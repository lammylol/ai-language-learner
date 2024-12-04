import functions from 'firebase-functions';
import {defineSecret} from 'firebase-functions/params';
import admin from 'firebase-admin';
import {genkit} from 'genkit';
import {googleAI, gemini15Flash} from '@genkit-ai/googleai';
import OpenAI from "openai";

// Initialize Firebase Admin SDK
admin.initializeApp();

// // Access the environment variable
const genApiKey = defineSecret('GENAPI_KEY');
const openAIKey = defineSecret('OPENAI_KEY');

// Function to initialize genkit with the API key
const initializeGenKit = async () => {
  const apiKey = genApiKey.value(); // Retrieve the secret value
  return genkit({
    plugins: [googleAI({apiKey})],
    model: gemini15Flash, // Set the default model
  });
};

const initializeOpenAI = async () => {
  const apiKey = openAIKey.value();

  // Initialize genkit with the API key
  return new OpenAI({
    apiKey: apiKey
  });
}

// Create the exports function for genKit.
export const processStringWithGenKit = functions.https.onRequest(
    {secrets: [genApiKey]},
    async (req, res) => {
    // // Grab the text parameter
    //   const original = req.query.text; query is used when running locally.

      console.log('Request body:', req.body);

      // Access the parameter from the Firebase callable function body. 
      // Production uses body.

      const systemInstruction = req.query.systemInstruction || req.body?.data?.systemInstruction || "";
      const prompt = req.query.prompt || req.body?.data?.prompt;

      if (typeof systemInstruction !== 'string' || !prompt || typeof prompt !== 'string') {
        console.error('Invalid input:', req.body);
        return res.status(400).json({
          error: 'Invalid input. Please provide a valid "systemInstruction" and "prompt" parameter.',
        });
      }

      try {
        // Initialize genkit with the API key
        const ai = await initializeGenKit();

        const request = { 
          prompt: prompt
        };
        // provide system instruction only if there is system instruction passed.
        if (systemInstruction.trim()) {
          request.system = systemInstruction;
        }
        const { text } = await ai.generate(request);

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

// Create the exports function for genKit.
export const processStringWithOpenAI = functions.https.onRequest(
  {secrets: [openAIKey] },
  async (req, res) => {
  // // Grab the text parameter
  //   const original = req.query.text; query is used when running locally.

    console.log('Request body:', JSON.stringify(req.body));

    const systemInstruction = req.query.systemInstruction || req.body?.data?.systemInstruction || "";
    // const prompt = req.query.prompt || req.body?.data?.prompt;
    const messages = req.query.messages ? JSON.parse(decodeURIComponent(req.query.messages)) : [];

    // if (typeof systemInstruction !== 'string' || !prompt || typeof prompt !== 'string') {
    //   console.error('Invalid input:', req.body);
    //   return res.status(400).json({
    //     error: 'Invalid input. Please provide a valid "systemInstruction" and "prompt" parameter.',
    //   });
    // }

    if (typeof systemInstruction !== 'string' || !messages || !Array.isArray(messages)) {
      console.error('Invalid input:', req.body);
      return res.status(400).json({
        error: 'Invalid input. Please provide a valid "systemInstruction" and "messages" parameter.',
      });
  }

    try {
      const ai = await initializeOpenAI();

      const messageJson = [
        ...(systemInstruction.trim()
        ? [
            {
              role: "system",
              content: systemInstruction,
            }
          ]
        : [])
      ];

      // Append message history, ensuring proper structure and types
      for (const message in messages) {  // Iterate over the elements directly
        if (
          message && 
          typeof message.text === 'string' && 
          typeof message.senderType === 'string'
        ) {
          messageJson.push({
            role: message.senderType === 'bot' ? "assistant" : "user",
            content: message.text,
          });
        } else {
          return res.status(400).json({
            error: 'Invalid message body.',
          });
        }
      }

      console.log(messageJson);

      // const tools = [
      //     {
      //       "type": "function",
      //       "function": {
      //         "name": "get_current_weather",
      //         "description": "Get the current weather in a given location",
      //         "parameters": {
      //           "type": "object",
      //           "properties": {
      //             "location": {
      //               "type": "string",
      //               "description": "The city and state, e.g. San Francisco, CA",
      //             },
      //             "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]},
      //           },
      //           "required": ["location"],
      //         },
      //       }
      //     }
      // ];

      const response = await ai.chat.completions.create({
        model: "gpt-4o-mini", // Ensure you're using a valid model, like gpt-4 or gpt-3.5-turbo
        messages: messageJson
      });
      
      // Accessing the response correctly
      const text = response.choices[0]?.message?.content || "No response from AI.";
      console.log(text);  // Logs the response text

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