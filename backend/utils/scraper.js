const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const axios = require('axios');

puppeteer.use(StealthPlugin());

const scrapeSinglePin = async (pinUrl) => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
    defaultViewport: null,
  });

  const page = await browser.newPage();
  const pinId = pinUrl.split("/pin/")[1].replace("/", "");

  try {
    await page.goto(pinUrl, {
      waitUntil: "domcontentloaded",
      timeout: 60000,
    });

    await page.waitForSelector("img", { timeout: 10000 });

    const data = await page.evaluate(() => {
        const title = document.querySelector('h1')?.innerText?.trim() || '';
      
        // Look for meta tag description
        const metaDesc = document.querySelector("meta[name='description']")?.content?.trim() || '';
      
        const imgEl = document.querySelector("img[src*='i.pinimg.com']");
        let imageUrl = imgEl?.src || '';
        if (imageUrl.includes('/236x/')) imageUrl = imageUrl.replace('/236x/', '/736x/');
      
        return {
          title,
          description: metaDesc,
          imageUrl,
          bodyText: document.body.innerText,
        };
      });

    if (!data || !data.imageUrl) throw new Error("Image URL not found");

    const imgRes = await axios.get(data.imageUrl, { responseType: "arraybuffer" });
    const base64Image = Buffer.from(imgRes.data).toString("base64");
    const contentType = imgRes.headers["content-type"];
    const fullBase64 = `data:${contentType};base64,${base64Image}`;

    await browser.close();
    return { ...data, image: base64Image, pinId }; 
  } catch (err) {
    await browser.close();
    console.error("Scrape error:", err.message);
    throw err;
  }
};

module.exports = { scrapeSinglePin };
