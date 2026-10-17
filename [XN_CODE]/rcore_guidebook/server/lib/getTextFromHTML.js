// ❗ Do not modify this file ❗
on("rcore_guidebook:getTextFromHTML", (html, cb) => {
  let strippedHTML = html.replace(/<[^>]*>/g, " "); // remove html tags
  strippedHTML = strippedHTML.replace(/&[^;]*;/g, " "); // remove html entities
  strippedHTML = strippedHTML.replace(/\s\s+/g, " "); // remove extra whitespace
  cb(strippedHTML);
});
