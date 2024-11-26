import functions from 'firebase-functions';
import {defineSecret} from 'firebase-functions/params';
import admin from 'firebase-admin';
import {genkit} from 'genkit';
import {googleAI, gemini15Flash} from '@genkit-ai/googleai';

// Initialize Firebase Admin SDK
admin.initializeApp();

// // Access the environment variable
const genApiKey = defineSecret('GENAPI_KEY');

// Function to initialize genkit with the API key
const initializeGenKit = async () => {
  const apiKey = genApiKey.value(); // Retrieve the secret value
  return genkit({
    plugins: [googleAI({apiKey})],
    model: gemini15Flash, // Set the default model
  });
};

// Create the exports function
export const processStringWithGenKit = functions.https.onRequest(
    {secrets: [genApiKey]},
    async (req, res) => {
    // // Grab the text parameter
    //   const original = req.query.text; query is used when running locally.

      console.log('Request body:', req.body);

      // Access the parameter from the Firebase callable function body. 
      // Production uses body.
      const original = req.body.data?.text;

      if (!original || typeof original !== 'string') {
        console.error('Invalid input:', req.body);
        return res.status(400).json({
          error: 'Invalid input. Please provide a valid "text" parameter.',
        });
      }

      try {
        // Initialize genkit with the API key
        const ai = await initializeGenKit();

        // Call genkit AI.
        const {text} = await ai.generate(original);

        // Send a 200 response with the result.
        console.log('AI Response generated:', text);
        res.status(200).json({
          result: text,
        });
      } catch (error) {
        // Send a 500 error for an internal server issue.
        console.error('Error occurred:', error);
        res.status(500).json({
          error: error.message || 'Failure: the process failed on the server.',
        });
      }
    });
