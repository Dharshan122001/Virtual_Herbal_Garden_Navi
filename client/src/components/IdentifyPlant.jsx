import React, { useState } from "react";
import axios from "axios";
import { AI_SERVICE_URL } from "../apiConfig";

function IdentifyPlant() {
  const [image, setImage] = useState(null);
  const [preview, setPreview] = useState("");
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);


  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setImage(file);
    setPreview(URL.createObjectURL(file));
    setResult(null);
    setError(null);
  };

  const handleRemove = () => {
    setImage(null);
    setPreview("");
    setResult(null);
    setError(null);
  };

  const handleIdentify = async () => {
    if (!image) {
      setError("Please select an image first.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("image", image);

    try {
      const res = await axios.post(
        `${AI_SERVICE_URL}/ai/identify`,
        formData,
        { headers: { "Content-Type": "multipart/form-data" } }
      );
      setResult(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || "Identification failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-xl mx-auto p-6 bg-white text-gray-800 rounded-xl shadow-lg border border-gray-100">
      <h2 className="text-2xl font-bold mb-6 text-center text-green-800">
        Identify Plant
      </h2>

      {/* ✅ FILE INPUT (Hidden if image selected) */}
      {!preview && (
        <label className="flex flex-col items-center justify-center w-full h-40 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors mb-4">
          <div className="flex flex-col items-center justify-center pt-5 pb-6">
            <p className="mb-2 text-sm text-gray-500">
              <span className="font-semibold">Click to upload</span> or drag and drop
            </p>
            <p className="text-xs text-gray-400">PNG, JPG or JPEG</p>
          </div>
          <input type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
        </label>
      )}

      {/* ✅ IMAGE PREVIEW & REMOVE */}
      {preview && (
        <div className="relative mb-4">
          <img
            src={preview}
            alt="Preview"
            className="w-full max-h-72 object-cover rounded-lg shadow-sm"
          />
          <button
            onClick={handleRemove}
            className="absolute top-2 right-2 bg-white/80 hover:bg-white text-red-600 p-2 rounded-full shadow transition-all"
          >
            {/* Simple X Icon */}
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      )}

      {/* ✅ IDENTIFY BUTTON */}
      <button
        onClick={handleIdentify}
        disabled={loading || !image}
        className="w-full bg-green-600 text-white py-3 rounded-lg font-semibold hover:bg-green-700 disabled:opacity-50 transition-colors shadow-md"
      >
        {loading ? "Analyzing..." : "Identify Plant"}
      </button>

      {/* ✅ ERROR & RESULTS (Stay the same) */}
      {error && <p className="text-red-600 text-center mt-4 bg-red-50 p-2 rounded">{error}</p>}
      
      {result && (
        <div className="mt-6 bg-green-50 p-6 rounded-lg border border-green-100">
          <h3 className="text-lg font-bold text-green-900 mb-2">{result.plant_name}</h3>
        </div>
      )}
    </div>
  );
}

export default IdentifyPlant;