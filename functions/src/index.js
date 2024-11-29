/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started


// import {onRequest} from 'firebase-functions/v2/https';
// import logger from 'firebase-functions/logger';
import {
  processStringWithGenKit,
} from './cloudfunctions.js'; // Assuming cloudfunctions.js is using ESM
export {processStringWithGenKit};

import {
  processStringWithOpenAI,
} from './cloudfunctions.js'; // Assuming cloudfunctions.js is using ESM
export {processStringWithOpenAI};