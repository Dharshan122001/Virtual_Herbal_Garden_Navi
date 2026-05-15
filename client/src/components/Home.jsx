// /client/src/components/Home.jsx
import React from 'react';
import { Link } from 'react-router-dom';

function Home() {
    return (
        <div className="text-center py-16 px-4 bg-gray-50 min-h-[calc(100vh-160px)] flex flex-col justify-center items-center">
            <h1 className="text-5xl font-extrabold text-green-700 mb-6 animate-fade-in-down">
                Welcome to Virtual Herbal Garden!
            </h1>
            <p className="text-xl text-gray-700 mb-8 max-w-2xl leading-relaxed animate-fade-in">
                Explore the fascinating world of medicinal plants. Discover their uses, scientific names,
                and even identify plants from images. Get insights from our AI assistant and bookmark your favorites!
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
                <Link
                    to="/plants"
                    className="bg-green-600 text-white font-bold py-3 px-8 rounded-full shadow-lg hover:bg-green-700 transition duration-300 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-opacity-75 text-lg"
                >
                    Browse Plants
                </Link>
                <Link
                    to="/identify"
                    className="bg-blue-600 text-white font-bold py-3 px-8 rounded-full shadow-lg hover:bg-blue-700 transition duration-300 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-75 text-lg"
                >
                    Identify a Plant
                </Link>
            </div>
            <p className="mt-12 text-md text-gray-600">
                "Nature itself is the best physician." - Hippocrates
            </p>
        </div>
    );
}

export default Home;