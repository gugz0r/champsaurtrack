<?php
// Open the SQLite database
$db = new SQLite3('data.db');

// Fetch all records from the tracking_data table
$results = $db->query('SELECT * FROM tracking_data ORDER BY timestamp DESC');

// Fetch data into an array
$data = [];
while ($row = $results->fetchArray(SQLITE3_ASSOC)) {
    $data[] = $row;
}

// Close the database connection
$db->close();
?>

<!DOCTYPE html>
<html>
<head>
    <title>Tracking Data</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f2f2f2;
            margin: 0;
            padding: 20px;
        }
        h1 {
            color: #333;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            background-color: #fff;
            margin-bottom: 20px;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4285F4;
            color: white;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .timestamp {
            color: #888;
            font-size: 0.9em;
        }
        #map {
            height: 500px;
        }
    </style>

    <!-- Include Leaflet CSS and JS for map display -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
</head>
<body>
    <h1>Tracking Data</h1>
    <table>
        <tr>
            <th>Name</th>
            <th>Number</th>
            <th>Latitude</th>
            <th>Longitude</th>
            <th>Timestamp</th>
        </tr>
        <?php foreach ($data as $entry): ?>
        <tr>
            <td><?php echo htmlspecialchars($entry['name']); ?></td>
            <td><?php echo htmlspecialchars($entry['number']); ?></td>
            <td><?php echo htmlspecialchars($entry['latitude']); ?></td>
            <td><?php echo htmlspecialchars($entry['longitude']); ?></td>
            <td class="timestamp"><?php echo htmlspecialchars($entry['timestamp']); ?></td>
        </tr>
        <?php endforeach; ?>
    </table>

    <div id="map"></div>

    <script>
        var map = L.map('map').setView([0, 0], 2);

        // Add OpenStreetMap tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap contributors'
        }).addTo(map);

        var markers = [
            <?php foreach ($data as $entry): ?>
            {
                name: '<?php echo htmlspecialchars($entry['name']); ?>',
                number: '<?php echo htmlspecialchars($entry['number']); ?>',
                latitude: <?php echo htmlspecialchars($entry['latitude']); ?>,
                longitude: <?php echo htmlspecialchars($entry['longitude']); ?>,
                timestamp: '<?php echo htmlspecialchars($entry['timestamp']); ?>'
            },
            <?php endforeach; ?>
        ];

        markers.forEach(function(marker) {
            L.marker([marker.latitude, marker.longitude]).addTo(map)
                .bindPopup('<strong>' + marker.name + '</strong><br>Number: ' + marker.number + '<br>Timestamp: ' + marker.timestamp);
        });

        // Adjust map bounds to show all markers
        if (markers.length > 0) {
            var group = new L.featureGroup(markers.map(function(marker) {
                return L.marker([marker.latitude, marker.longitude]);
            }));
            map.fitBounds(group.getBounds());
        }
    </script>
</body>
</html>
