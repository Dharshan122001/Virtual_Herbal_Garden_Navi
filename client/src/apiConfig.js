export const PLANT_SERVICE_URL =
  window.appConfig?.VITE_PLANT_API_URL || "/api/plant";

export const AUTH_SERVICE_URL =
  window.appConfig?.VITE_AUTH_API_URL || "/api/auth";

export const AI_SERVICE_URL =
  window.appConfig?.VITE_AI_API_URL || "/api/ai";

console.log("window.appConfig:", window.appConfig);

console.log("PLANT_SERVICE_URL:", PLANT_SERVICE_URL);
console.log("AUTH_SERVICE_URL:", AUTH_SERVICE_URL);
console.log("AI_SERVICE_URL:", AI_SERVICE_URL);