import { mockIPC } from '@tauri-apps/api/mocks';
import '@testing-library/jest-dom/vitest'

// Setup the IPC mock globally
mockIPC(() => {
    // Add your conditional logic for different commands here
    return Promise.resolve();
  });
