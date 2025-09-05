<?php
// Webhook deployment script for zazadance.com
// This file should be placed on your server to auto-update from GitHub

// Security token (you should set this in your webhook)
$secret = 'zazadance-deploy-secret-2024';

// Get the payload
$payload = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';

// Verify signature (optional but recommended)
if ($signature) {
    $expected_signature = 'sha256=' . hash_hmac('sha256', $payload, $secret);
    if (!hash_equals($expected_signature, $signature)) {
        http_response_code(401);
        exit('Unauthorized');
    }
}

// Parse the payload
$data = json_decode($payload, true);

// Only deploy on push to main branch
if (isset($data['ref']) && $data['ref'] === 'refs/heads/main') {
    
    // Log the deployment
    file_put_contents('/var/log/zazadance-deploy.log', 
        date('Y-m-d H:i:s') . " - Deployment triggered\n", 
        FILE_APPEND | LOCK_EX);
    
    // Commands to update your server
    $commands = [
        'cd /path/to/your/zazadance/directory',
        'git fetch origin main',
        'git reset --hard origin/main',
        'cp -r docs/admin/* /var/www/html/admin/',
        'echo "' . date('Y-m-d H:i:s') . '" > /var/www/html/admin/last_updated.txt'
    ];
    
    foreach ($commands as $command) {
        exec($command . ' 2>&1', $output, $return_code);
        
        if ($return_code !== 0) {
            file_put_contents('/var/log/zazadance-deploy.log', 
                "ERROR: Command failed: $command\nOutput: " . implode("\n", $output) . "\n", 
                FILE_APPEND | LOCK_EX);
            http_response_code(500);
            exit('Deployment failed');
        }
    }
    
    file_put_contents('/var/log/zazadance-deploy.log', 
        "SUCCESS: Deployment completed at " . date('Y-m-d H:i:s') . "\n", 
        FILE_APPEND | LOCK_EX);
    
    echo 'Deployment successful';
} else {
    echo 'No deployment needed';
}
?>