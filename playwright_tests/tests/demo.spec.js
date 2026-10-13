const { test, expect } = require('@playwright/test');

test.describe('RentaTool Mobile - Visual UI Automation', () => {
  
  test('TC-01: App Boots Successfully and Renders Login Screen', async ({ page }) => {
    // Navigate to the local Flutter Web Server
    await page.goto('/');

    // Wait for the Flutter engine to initialize (Flutter renders into a flt-glass-pane canvas)
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 15000 });
    
    // Wait an additional moment for the initial rendering animation to finish
    await page.waitForTimeout(3000);

    // Take a screenshot of the initial load state to prove the app booted
    await page.screenshot({ path: 'screenshots/app_boot_success.png' });

    // Since Flutter Web uses CanvasKit, standard HTML DOM selectors won't work natively 
    // without Semantics enabled. For this demo, we perform a visual test and coordinate clicks.
    
    // Click roughly in the center of the screen to focus the app
    await page.mouse.click(500, 500);
    
    // Prove the page title is correct (Flutter sets the HTML <title>)
    await expect(page).toHaveTitle(/RentaTool/i);
  });

  test('TC-02: Form Interaction & Error Validation Screenshot', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { state: 'attached' });
    await page.waitForTimeout(3000);

    // Click where the "Sign In" button approximately is (Coord: X:640, Y: 600 based on Desktop Chrome)
    // In a real Playwright+Flutter setup, you'd use "flutter run -d web-server --web-renderer html" 
    // or accessibility features to target elements.
    const boundingBox = await page.locator('body').boundingBox();
    if (boundingBox) {
       await page.mouse.click(boundingBox.width / 2, boundingBox.height / 2 + 150);
    }
    
    await page.waitForTimeout(1000); // Wait for the red error validation to appear

    // Capture the validation error state
    await page.screenshot({ path: 'screenshots/form_validation_errors.png' });
  });

});
