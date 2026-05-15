import React from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import { FaBookmark, FaRegBookmark } from 'react-icons/fa';
import { PLANT_SERVICE_URL } from "../apiConfig";

function PlantCard({ plant, userBookmarks, onBookmarkToggled }) {

    const isBookmarked = userBookmarks.has(plant.plant_id);
    
    const token = localStorage.getItem('token');
    const dbUser = JSON.parse(localStorage.getItem('user'));

    const handleBookmark = async (event) => {
        event.stopPropagation();
        event.preventDefault();

        if (!token || !dbUser) {
            alert("Please login to bookmark plants!");
            return;
        }

        try {
            const config = {
                headers: { Authorization: `Bearer ${token}` }
            };

            // Use the actual email field from your stored user object
            const userEmail = dbUser.email; 

            if (isBookmarked) {
                await axios.delete(`${PLANT_SERVICE_URL}/bookmarks/${userEmail}/${plant.plant_id}`, config);
            } else {
                const bookmarkData = {
                    plant_id: plant.plant_id,
                    email: userEmail 
                };
                await axios.post(`${PLANT_SERVICE_URL}/bookmarks/`, bookmarkData, config);
            }

            if (onBookmarkToggled) {
                onBookmarkToggled(plant.plant_id, isBookmarked);
            }
        } catch (error) {
            const errorMsg = error.response?.data?.detail || "Failed to update bookmark.";
            alert(errorMsg);
        }
    };

    return (
        <div className="bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300 overflow-hidden border border-gray-200 relative">
            <button
                onClick={handleBookmark}
                className="absolute top-3 right-3 z-10 p-2 rounded-full bg-white bg-opacity-85 hover:bg-opacity-100 shadow-md"
            >
                {isBookmarked ? (
                    <FaBookmark className="text-xl text-yellow-500" />
                ) : (
                    <FaRegBookmark className="text-xl text-gray-800" />
                )}
            </button>

            <Link to={`/plants/${plant.plant_id}`} className="block">
                {plant.image_url ? (
                    <img src={plant.image_url} alt={plant.common_name} className="w-full h-48 object-cover" />
                ) : (
                    <div className="w-full h-48 bg-gray-200 flex items-center justify-center text-gray-500">No Image</div>
                )}
                <div className="p-4 text-center">
                    <h3 className="text-lg font-semibold text-gray-800">{plant.common_name}</h3>
                </div>
            </Link>
        </div>
    );
}

export default PlantCard;