// Runs the Firestore security rules tests.
//
// `firebase emulators:exec` cannot be used here: it starts the emulator fine
// but then the emulator process dies with exit code 3221225786 as soon as the
// test command starts. Running the same JAR directly avoids the emulator hub
// that appears to be killing it, so this script does the lifecycle by hand.

const fs = require("fs");
const os = require("os");
const net = require("net");
const path = require("path");
const { spawn } = require("child_process");
const Mocha = require("mocha");

const HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
const TESTS_DIR = __dirname;
const RULES_FILE = path.join(__dirname, "..", "firestore.rules");
const EMULATOR_CACHE = path.join(os.homedir(), ".cache", "firebase", "emulators");

function findEmulatorJar() {
  // Override for machines where the emulator cache lives outside the home
  // directory, which is the case here because the C: drive is full.
  if (process.env.FIRESTORE_EMULATOR_JAR) {
    return fs.existsSync(process.env.FIRESTORE_EMULATOR_JAR)
      ? process.env.FIRESTORE_EMULATOR_JAR
      : null;
  }

  if (!fs.existsSync(EMULATOR_CACHE)) {
    return null;
  }

  const jar = fs
    .readdirSync(EMULATOR_CACHE)
    .find((name) => /^cloud-firestore-emulator-.*\.jar$/.test(name));

  return jar ? path.join(EMULATOR_CACHE, jar) : null;
}

function waitForPort(address, timeoutMs) {
  const deadline = Date.now() + timeoutMs;

  return new Promise((resolve, reject) => {
    const attempt = () => {
      const socket = net.connect(address.port, address.host);

      socket.once("connect", () => {
        socket.destroy();
        resolve();
      });

      socket.once("error", () => {
        socket.destroy();
        if (Date.now() > deadline) {
          reject(new Error(`Emulator did not open ${address.host}:${address.port}`));
          return;
        }
        setTimeout(attempt, 250);
      });
    };

    attempt();
  });
}

function runTests() {
  const mocha = new Mocha({ reporter: "spec", timeout: 30000 });

  fs
    .readdirSync(TESTS_DIR)
    .filter((name) => name.endsWith(".test.js"))
    .forEach((name) => mocha.addFile(path.join(TESTS_DIR, name)));

  process.env.FIRESTORE_EMULATOR_HOST = HOST;

  return new Promise((resolve) => {
    mocha.loadFiles(() => {
      mocha.run((failures) => resolve(failures === 0 ? 0 : 1));
    });
  });
}

function readLog(logFile) {
  try {
    return fs.readFileSync(logFile, "utf8");
  } catch {
    return "(no emulator log was written)";
  }
}

function isPortOpen(address) {
  return new Promise((resolve) => {
    const socket = net.connect(address.port, address.host);

    socket.once("connect", () => {
      socket.destroy();
      resolve(true);
    });

    socket.once("error", () => {
      socket.destroy();
      resolve(false);
    });
  });
}

async function main() {
  const jar = findEmulatorJar();

  if (!jar) {
    console.error(
      `No Firestore emulator found in ${EMULATOR_CACHE}.\n` +
        "Download it once by running: firebase emulators:start --only firestore\n" +
        "Or point FIRESTORE_EMULATOR_JAR at the jar if it is cached elsewhere.",
    );
    return 1;
  }

  const address = { host: HOST.split(":")[0], port: Number(HOST.split(":")[1]) };

  // An emulator left over from an earlier run would silently serve the tests
  // with stale rules, which produces confusing results. Refuse instead.
  if (await isPortOpen(address)) {
    console.error(
      `Port ${address.port} is already in use, so the tests would run against an\n` +
        "emulator that is already running. Stop it first, or set\n" +
        "FIRESTORE_EMULATOR_HOST to a free port.",
    );
    return 1;
  }

  console.log(`Starting Firestore emulator from ${path.basename(jar)}`);

  // The emulator logs heavily. Leaving stdout on a pipe that nobody reads
  // fills the buffer and hangs the emulator, so send it to a file instead and
  // only show it if something goes wrong.
  const logFile = path.join(os.tmpdir(), "firestore-emulator.log");
  const logStream = fs.createWriteStream(logFile, { flags: "w" });

  const emulator = spawn("java", [
    "-jar",
    jar,
    `--host=${address.host}`,
    `--port=${address.port}`,
    `--rules=${RULES_FILE}`,
  ], { stdio: ["ignore", "pipe", "pipe"] });

  emulator.stdout.pipe(logStream);
  emulator.stderr.pipe(logStream);

  emulator.on("error", (error) => {
    console.error(`Could not start the emulator: ${error.message}`);
  });

  try {
    await waitForPort(address, 60000);
  } catch (error) {
    console.error(`${error.message}\n\nEmulator log:\n${readLog(logFile)}`);
    emulator.kill();
    return 1;
  }

  let exitCode = 1;

  try {
    exitCode = await runTests();
  } finally {
    emulator.kill();
  }

  if (exitCode !== 0) {
    console.error(`\nEmulator log:\n${readLog(logFile)}`);
  }

  return exitCode;
}

main().then((code) => {
  process.exit(code);
});