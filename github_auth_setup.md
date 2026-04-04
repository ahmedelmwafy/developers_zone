# GitHub Sign-In Configuration Guide

I have already implemented the code and logic to handle GitHub sign-in and profile synchronization within the application. To activate this high-fidelity technical node, you must complete the following configuration steps in the GitHub and Firebase consoles.

---

### Step 1: Create a GitHub OAuth App
1.  Go to your **[GitHub Developer Settings](https://github.com/settings/developers)**.
2.  Select **OAuth Apps** and click **New OAuth App**.
3.  **Application Name**: `Developers Zone` (or your preferred name).
4.  **Homepage URL**: `https://developers-zone-f7e91.firebaseapp.com` (Your Firebase URL).
5.  **Authorization callback URL**: You will get this from the Firebase console in the next step.
6.  Click **Register application**.
7.  Copy the **Client ID** and generate a **Client Secret**. Keep these safe.

---

### Step 2: Enable GitHub in Firebase Console
1.  Go to the **[Firebase Console](https://console.firebase.google.com/)**.
2.  Select your project and go to **Authentication** > **Sign-in method**.
3.  Click **Add new provider** and select **GitHub**.
4.  Toggle **Enable**.
5.  Paste the **Client ID** and **Client Secret** you generated in Step 1.
6.  **CRITICAL**: Copy the **Redirect URI** shown in the Firebase config window (usually looks like `https://project-id.firebaseapp.com/__/auth/handler`).

---

### Step 3: Finalize GitHub Configuration
1.  Go back to your **GitHub OAuth App settings**.
2.  Paste the **Redirect URI** from Step 2 into the **Authorization callback URL** field.
3.  **Save changes**.

---

### Resulting Automated Features
Once these steps are complete, the application will automatically:
-   **Synchronize Professional Metadata**: Harvest GitHub Bio, Company (as Position), and Location (City/Country).
-   **Establish Nodal Identity**: Auto-populate Name, Email, and Profile Avatars.
-   **Verifying Developer Status**: Ensure the user enters the "Digital Obsidian" ecosystem as an elite, pre-verified contributor.

> [!IMPORTANT]
> The application code is already fully prepared to handle this data. No further code changes are required after completing these external configuration steps.
