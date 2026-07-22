import { useEffect, useMemo, useState } from "react";
import ConfirmDialog from "../components/ConfirmDialog";
import EmptyState from "../components/EmptyState";
import LoadingSpinner from "../components/LoadingSpinner";
import MessageBanner from "../components/MessageBanner";
import StatusBadge from "../components/StatusBadge";
import {
  createCategory,
  getCategories,
  setCategoryActive,
  updateCategory,
} from "../services/categoryService";
import { getDataErrorMessage } from "../utils/formatters";

const emptyForm = {
  name: "",
  description: "",
  iconPath: "",
  active: true,
  sortOrder: "",
};

function CategoriesPage() {
  const [categories, setCategories] = useState([]);
  const [searchText, setSearchText] = useState("");
  const [editingCategory, setEditingCategory] = useState(null);
  const [categoryForm, setCategoryForm] = useState(emptyForm);
  const [categoryToDeactivate, setCategoryToDeactivate] = useState(null);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [formError, setFormError] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");

  useEffect(() => {
    let isActive = true;

    async function loadCategories() {
      try {
        const categoryList = await getCategories();
        if (isActive) {
          setCategories(categoryList);
        }
      } catch (error) {
        console.error("Categories could not be loaded:", error);
        if (isActive) {
          setErrorMessage(
            getDataErrorMessage(
              error,
              "Categories could not be loaded. Please refresh the page.",
            ),
          );
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    }

    loadCategories();
    return () => {
      isActive = false;
    };
  }, []);

  const visibleCategories = useMemo(() => {
    const queryText = searchText.trim().toLowerCase();

    return categories.filter(
      (category) =>
        !queryText ||
        category.name?.toLowerCase().includes(queryText) ||
        category.description?.toLowerCase().includes(queryText),
    );
  }, [categories, searchText]);

  function openAddForm() {
    setEditingCategory(null);
    setCategoryForm(emptyForm);
    setFormError("");
    setIsFormOpen(true);
  }

  function openEditForm(category) {
    setEditingCategory(category);
    setCategoryForm({
      name: category.name || "",
      description: category.description || "",
      iconPath: category.iconPath || "",
      active: Boolean(category.active),
      sortOrder: String(category.sortOrder ?? ""),
    });
    setFormError("");
    setIsFormOpen(true);
  }

  function closeForm() {
    setIsFormOpen(false);
    setEditingCategory(null);
    setCategoryForm(emptyForm);
    setFormError("");
  }

  function updateFormField(field, value) {
    setCategoryForm((current) => ({ ...current, [field]: value }));
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setFormError("");
    setErrorMessage("");
    setSuccessMessage("");

    const sortOrder = Number(categoryForm.sortOrder);
    if (!categoryForm.name.trim()) {
      setFormError("Category name is required.");
      return;
    }
    if (
      categoryForm.sortOrder === "" ||
      !Number.isInteger(sortOrder) ||
      sortOrder < 0
    ) {
      setFormError("Sort order must be a whole number of zero or more.");
      return;
    }

    const categoryData = { ...categoryForm, sortOrder };
    setIsProcessing(true);

    try {
      if (editingCategory) {
        await updateCategory(editingCategory.id, categoryData);
        setCategories((currentCategories) =>
          currentCategories
            .map((category) =>
              category.id === editingCategory.id
                ? { ...category, ...categoryData }
                : category,
            )
            .sort((first, second) => first.sortOrder - second.sortOrder),
        );
        setSuccessMessage(`${categoryData.name} was updated.`);
      } else {
        const categoryId = await createCategory(categoryData);
        setCategories((currentCategories) =>
          [...currentCategories, { id: categoryId, ...categoryData }].sort(
            (first, second) => first.sortOrder - second.sortOrder,
          ),
        );
        setSuccessMessage(`${categoryData.name} was added.`);
      }

      closeForm();
    } catch (error) {
      console.error("Category could not be saved:", error);
      if (error?.code === "category/already-exists") {
        setFormError("A category with this name already exists.");
      } else {
        setFormError(
          getDataErrorMessage(error, "The category could not be saved."),
        );
      }
    } finally {
      setIsProcessing(false);
    }
  }

  async function activateCategory(category) {
    setErrorMessage("");
    setSuccessMessage("");
    setIsProcessing(true);

    try {
      await setCategoryActive(category.id, true);
      updateCategoryActiveState(category.id, true);
      setSuccessMessage(`${category.name} is active.`);
    } catch (error) {
      console.error("Category could not be activated:", error);
      setErrorMessage(
        getDataErrorMessage(error, "The category could not be activated."),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  async function confirmDeactivation() {
    if (!categoryToDeactivate) {
      return;
    }

    setErrorMessage("");
    setSuccessMessage("");
    setIsProcessing(true);

    try {
      await setCategoryActive(categoryToDeactivate.id, false);
      updateCategoryActiveState(categoryToDeactivate.id, false);
      setSuccessMessage(`${categoryToDeactivate.name} was deactivated.`);
      setCategoryToDeactivate(null);
    } catch (error) {
      console.error("Category could not be deactivated:", error);
      setErrorMessage(
        getDataErrorMessage(error, "The category could not be deactivated."),
      );
    } finally {
      setIsProcessing(false);
    }
  }

  function updateCategoryActiveState(categoryId, active) {
    setCategories((currentCategories) =>
      currentCategories.map((category) =>
        category.id === categoryId ? { ...category, active } : category,
      ),
    );
  }

  if (isLoading) {
    return <LoadingSpinner label="Loading categories..." />;
  }

  return (
    <div className="page-stack">
      <section className="page-intro page-intro-actions">
        <div>
          <h2>Service categories</h2>
          <p>
            Add, edit, order, and deactivate the categories used by the mobile
            application.
          </p>
        </div>
        <button
          type="button"
          className="button button-primary"
          onClick={openAddForm}
        >
          Add category
        </button>
      </section>

      <MessageBanner
        message={errorMessage}
        type="error"
        onDismiss={() => setErrorMessage("")}
      />
      <MessageBanner
        message={successMessage}
        type="success"
        onDismiss={() => setSuccessMessage("")}
      />

      <section className="content-card">
        <div className="filter-bar">
          <label className="search-control">
            <span className="sr-only">Search categories</span>
            <input
              type="search"
              placeholder="Search categories"
              value={searchText}
              onChange={(event) => setSearchText(event.target.value)}
            />
          </label>
        </div>

        {visibleCategories.length === 0 ? (
          <EmptyState
            title="No categories found"
            message={
              categories.length === 0
                ? "Add the first service category to get started."
                : "Try changing the search text."
            }
          />
        ) : (
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Category</th>
                  <th>Description</th>
                  <th>Icon path</th>
                  <th>Status</th>
                  <th>Sort order</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {visibleCategories.map((category) => (
                  <tr key={category.id}>
                    <td>
                      <div className="category-name-cell">
                        <span className="category-icon" aria-hidden="true">
                          {(category.name?.[0] || "?").toUpperCase()}
                        </span>
                        <span>
                          <strong>{category.name}</strong>
                          <small>{category.id}</small>
                        </span>
                      </div>
                    </td>
                    <td>{category.description || "Not provided"}</td>
                    <td className="path-cell">
                      {category.iconPath || "Not provided"}
                    </td>
                    <td>
                      <StatusBadge
                        status={category.active ? "active" : "inactive"}
                      />
                    </td>
                    <td>{category.sortOrder}</td>
                    <td>
                      <div className="action-group">
                        <button
                          type="button"
                          className="button button-small button-secondary"
                          onClick={() => openEditForm(category)}
                          disabled={isProcessing}
                        >
                          Edit
                        </button>
                        {category.active ? (
                          <button
                            type="button"
                            className="button button-small button-danger-soft"
                            onClick={() => setCategoryToDeactivate(category)}
                            disabled={isProcessing}
                          >
                            Deactivate
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="button button-small button-success-soft"
                            onClick={() => activateCategory(category)}
                            disabled={isProcessing}
                          >
                            Activate
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {isFormOpen && (
        <div className="modal-backdrop" role="presentation">
          <div
            className="modal-card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="category-form-title"
          >
            <div className="card-heading">
              <div>
                <h2 id="category-form-title">
                  {editingCategory ? "Edit category" : "Add category"}
                </h2>
                <p>
                  New category IDs are generated as readable lowercase slugs.
                </p>
              </div>
              <button
                type="button"
                className="icon-button"
                aria-label="Close category form"
                onClick={closeForm}
                disabled={isProcessing}
              >
                ×
              </button>
            </div>

            <MessageBanner message={formError} type="error" />

            <form className="form-stack" onSubmit={handleSubmit} noValidate>
              <label className="form-field">
                <span>Category name *</span>
                <input
                  type="text"
                  value={categoryForm.name}
                  onChange={(event) =>
                    updateFormField("name", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>
              <label className="form-field">
                <span>Description</span>
                <textarea
                  rows="3"
                  value={categoryForm.description}
                  onChange={(event) =>
                    updateFormField("description", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>
              <label className="form-field">
                <span>Icon path</span>
                <input
                  type="text"
                  value={categoryForm.iconPath}
                  placeholder="categories/electrician_icon.png"
                  onChange={(event) =>
                    updateFormField("iconPath", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>
              <label className="form-field">
                <span>Sort order *</span>
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={categoryForm.sortOrder}
                  onChange={(event) =>
                    updateFormField("sortOrder", event.target.value)
                  }
                  disabled={isProcessing}
                />
              </label>
              <label className="checkbox-field">
                <input
                  type="checkbox"
                  checked={categoryForm.active}
                  onChange={(event) =>
                    updateFormField("active", event.target.checked)
                  }
                  disabled={isProcessing}
                />
                <span>Category is active</span>
              </label>

              <div className="modal-actions">
                <button
                  type="button"
                  className="button button-secondary"
                  onClick={closeForm}
                  disabled={isProcessing}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="button button-primary"
                  disabled={isProcessing}
                >
                  {isProcessing
                    ? "Saving..."
                    : editingCategory
                      ? "Save changes"
                      : "Add category"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={Boolean(categoryToDeactivate)}
        title="Deactivate this category?"
        message={
          categoryToDeactivate
            ? `${categoryToDeactivate.name} will no longer appear as an active service category. Existing records are kept.`
            : ""
        }
        confirmLabel="Deactivate"
        confirmTone="danger"
        isProcessing={isProcessing}
        onCancel={() => setCategoryToDeactivate(null)}
        onConfirm={confirmDeactivation}
      />
    </div>
  );
}

export default CategoriesPage;
