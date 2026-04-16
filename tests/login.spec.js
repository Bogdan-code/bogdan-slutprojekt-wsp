import { test, expect } from '@playwright/test';

test('användare kan logga in', async ({ page }) => {
  await page.goto('http://localhost:9292/user/login');

  await page.getByLabel('Namn').fill('admin');
  await page.getByLabel('Lösenord').fill('admin');
  await page.getByRole('button', { value: 'Log in' }).click();

  await page.goto('http://localhost:9292/pizzas/create');
  await expect(page).toHaveURL('http://localhost:9292/pizzas/create');
});

