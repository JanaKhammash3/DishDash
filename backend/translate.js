const { TranslationServiceClient } = require('@google-cloud/translate').v3;

const client = new TranslationServiceClient({
  keyFilename: './credentials/crack-decorator-431008-t5-13af830d0b6c.json',
});
const projectId = 'crack-decorator-431008-t5'; // ⚠️ Replace with your actual project ID
const location = 'global';

async function translateText(text, targetLang = 'ar') {
  const request = {
    parent: `projects/${projectId}/locations/${location}`,
    contents: [text],
    mimeType: 'text/plain', // or 'text/html'
    sourceLanguageCode: 'en',
    targetLanguageCode: targetLang,
  };

  const [response] = await client.translateText(request);
  return response.translations[0].translatedText;
}

module.exports = { translateText };