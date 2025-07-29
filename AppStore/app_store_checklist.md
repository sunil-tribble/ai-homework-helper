# App Store Submission Checklist

## Pre-Submission Requirements

### ✅ Apple Developer Account
- [ ] $99/year Apple Developer Program membership active
- [ ] Tax forms completed (W-9 or W-8BEN)
- [ ] Banking information added for payments
- [ ] Agreements signed in App Store Connect

### ✅ App Information
- [x] App Name: AI Homework Helper
- [x] Bundle ID: com.aihomeworkhelper.ios
- [x] Version: 1.0.0
- [x] Build: 1
- [x] Category: Education
- [x] Age Rating: 4+

### ✅ App Store Assets
- [x] App Description (4000 chars max) 
- [x] Keywords (100 chars max)
- [x] What's New text
- [ ] App Icon (1024x1024 PNG, no transparency)
- [ ] Screenshots (at least 3, up to 10)
- [ ] App Preview Video (optional)

### ✅ Technical Requirements
- [x] iOS 17.0 minimum deployment target
- [x] Universal app (iPhone & iPad)
- [x] No crashes or bugs
- [x] All features functional
- [ ] TestFlight beta testing completed

### ✅ Privacy & Legal
- [x] Privacy Policy URL live (see app_store_urls.txt)
- [x] Terms of Service URL live (see app_store_urls.txt)
- [ ] Deploy to GitHub Pages (run deploy-github-pages.sh)
- [ ] EULA if needed
- [ ] Copyright permissions for all content
- [ ] Third-party licenses documented

### ✅ In-App Purchases
- [x] Product IDs defined in code
- [ ] IAPs created in App Store Connect
- [ ] IAP descriptions and pricing set
- [ ] Subscription terms clear
- [ ] Restore purchases functional

### ✅ Backend & Security
- [x] API key removed from app
- [x] Backend deployed and tested
- [ ] SSL certificates valid
- [ ] Rate limiting implemented
- [ ] Error handling for network issues

## Submission Steps

1. **Archive Build in Xcode**
   ```
   Product → Archive
   Validate
   Distribute App → App Store Connect
   ```

2. **Configure in App Store Connect**
   - Create new app
   - Fill in all metadata
   - Upload screenshots
   - Set pricing and availability
   - Add in-app purchases
   - Submit for review

3. **Common Rejection Reasons to Avoid**
   - Crashes or bugs
   - Broken features
   - Misleading metadata
   - Inappropriate content
   - Missing privacy policy
   - IAP issues

## Post-Submission

- [ ] Monitor review status
- [ ] Respond to reviewer questions within 24 hours
- [ ] Prepare day-one patch if needed
- [ ] Plan marketing for launch day
- [ ] Set up app analytics

## Estimated Timeline
- Submission to Review: 24-48 hours
- Review Process: 2-7 days
- If rejected: Fix and resubmit within 2 days