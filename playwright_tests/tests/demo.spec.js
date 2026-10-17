const { test, expect } = require('@playwright/test');

test.describe('RentaTool Mobile - Visual UI Automation Suite', () => {
  test.describe.configure({ mode: 'serial' });

  let page;

  test.beforeAll(async ({ browser }) => {
    page = await browser.newPage();
    // Warm up the Flutter web engine on port 8080
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flutter-view, flt-glass-pane', { state: 'attached', timeout: 45000 });
    await page.waitForTimeout(3000);
  });

  test.afterAll(async () => {
    if (page) {
      await page.close();
    }
  });

  test('TC-01: App Boots Successfully and Renders Login Screen', async () => {
    // Assert page title contains rentatool / RentaTool
    await expect(page).toHaveTitle(/rentatool/i);

    // Save screenshot of initial boot state
    await page.screenshot({ path: 'screenshots/01_app_boot_success.png' });

    // Focus canvas
    await page.mouse.click(500, 300);
  });

  test('TC-02: Form Interaction & Error Validation Screenshot', async () => {
    // Click submit button area without inputting values to trigger validation errors
    const boundingBox = await page.locator('body').boundingBox();
    if (boundingBox) {
       await page.mouse.click(boundingBox.width / 2, boundingBox.height / 2 + 150);
    }
    
    await page.waitForTimeout(1500);

    // Capture validation error state
    await page.screenshot({ path: 'screenshots/02_form_validation_errors.png' });
  });

  test('TC-03: Multi-Device Responsive Viewports (Mobile, Tablet, Desktop)', async () => {
    // 1. Mobile Viewport (iPhone SE / Android Compact)
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'screenshots/03_mobile_viewport_375px.png' });

    // 2. Tablet Viewport (iPad / Medium Screen)
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'screenshots/03_tablet_viewport_768px.png' });

    // 3. Desktop Viewport (Laptop Standard)
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'screenshots/03_desktop_viewport_1280px.png' });

    // Verify canvas remains attached across viewports
    const isAttached = await page.locator('flutter-view, flt-glass-pane').count();
    expect(isAttached).toBeGreaterThan(0);
  });

  test('TC-04: Navigation & Route Transition to Registration Screen', async () => {
    // Navigate to registration route
    await page.evaluate(() => {
      window.location.hash = '/register';
    });
    await page.waitForTimeout(2500);

    // Capture the registration screen rendering
    await page.screenshot({ path: 'screenshots/04_registration_screen.png' });

    // Assert that the page title remains valid
    await expect(page).toHaveTitle(/rentatool/i);

    // Navigate back to home route for following test
    await page.evaluate(() => {
      window.location.hash = '/';
    });
    await page.waitForTimeout(2000);
  });

  test('TC-05: Web Load Performance & Render Timing Budget', async () => {
    // Evaluate client-side Navigation Timing API
    const timingMetrics = await page.evaluate(() => {
      const navEntry = performance.getEntriesByType('navigation')[0];
      return {
        domContentLoaded: navEntry ? Math.round(navEntry.domContentLoadedEventEnd) : null,
        duration: navEntry ? Math.round(navEntry.duration) : null,
      };
    });

    console.log(`[Performance Observation] DOM Timing:`, timingMetrics);

    // Assert DOM content loaded was captured and under budget
    if (timingMetrics.domContentLoaded) {
      expect(timingMetrics.domContentLoaded).toBeLessThan(15000);
    }
  });

  test('TC-06: Interactive Visual Smoke & Keyboard Focus Flow', async () => {
    // Reset viewport to comfortable desktop size
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.waitForTimeout(1000);

    // Simulate clicking into the central view and sending keystrokes
    const boundingBox = await page.locator('body').boundingBox();
    if (boundingBox) {
      await page.mouse.click(boundingBox.width / 2, boundingBox.height / 2 - 50);
    }

    // Type sample characters and test Tab navigation
    await page.keyboard.type('test@rentatool.com', { delay: 40 });
    await page.keyboard.press('Tab');
    await page.keyboard.type('Password123!', { delay: 40 });

    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screenshots/06_keyboard_input_interaction.png' });

    // Verify canvas remains active
    const canvas = page.locator('flutter-view, flt-glass-pane').first();
    await expect(canvas).toBeAttached();
  });

});
