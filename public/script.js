document.addEventListener("click", function (event) {
  const button = event.target.closest(".qty-btn");
  if (!button) return;

  const form = button.closest(".cart-form");
  if (!form) return;

  const input = form.querySelector(".qty-input");
  if (!input) return;

  let value = parseInt(input.value, 10) || 1;

  if (button.dataset.action === "minus") {
    value = Math.max(1, value - 1);
  }

  if (button.dataset.action === "plus") {
    value = value + 1;
  }

  input.value = value;
});