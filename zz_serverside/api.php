<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Set the content type to application/json
header("Content-Type: application/json");

// Allow POST requests from any origin
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Read the incoming POST data
$inputJSON = file_get_contents('php://input');

// Decode the JSON into a PHP associative array
$input = json_decode($inputJSON, true);

// Check if decoding was successful
if (json_last_error() === JSON_ERROR_NONE) {
    // Extract data from the input
    $name = $input['name'] ?? 'undefined';
    $number = $input['number'] ?? 'undefined';
    $latitude = $input['latitude'] ?? 'undefined';
    $longitude = $input['longitude'] ?? 'undefined';
    $timestamp = $input['timestamp'] ?? 'undefined';

    // Open or create the SQLite database
    $db = new SQLite3('data.db');

    // Create the table if it doesn't exist
    $db->exec("CREATE TABLE IF NOT EXISTS tracking_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        number TEXT,
        latitude TEXT,
        longitude TEXT,
        timestamp TEXT
    )");

    // Prepare an SQL statement to prevent SQL injection
    $stmt = $db->prepare('INSERT INTO tracking_data (name, number, latitude, longitude, timestamp) VALUES (:name, :number, :latitude, :longitude, :timestamp)');
    $stmt->bindValue(':name', $name, SQLITE3_TEXT);
    $stmt->bindValue(':number', $number, SQLITE3_TEXT);
    $stmt->bindValue(':latitude', $latitude, SQLITE3_TEXT);
    $stmt->bindValue(':longitude', $longitude, SQLITE3_TEXT);
    $stmt->bindValue(':timestamp', $timestamp, SQLITE3_TEXT);

    // Execute the statement
    if ($stmt->execute()) {
        // Send a success response back as JSON
        echo json_encode([
            "status" => "success",
            "message" => "Data received and stored successfully",
            "received_data" => [
                "name" => $name,
                "number" => $number,
                "latitude" => $latitude,
                "longitude" => $longitude,
                "timestamp" => $timestamp
            ]
        ]);
    } else {
        // Send an error response if data could not be stored
        echo json_encode([
            "status" => "error",
            "message" => "Failed to store data"
        ]);
    }

    // Close the database connection
    $db->close();
} else {
    // If JSON decoding failed, return an error response
    echo json_encode([
        "status" => "error",
        "message" => "Invalid JSON received"
    ]);
}
?>
