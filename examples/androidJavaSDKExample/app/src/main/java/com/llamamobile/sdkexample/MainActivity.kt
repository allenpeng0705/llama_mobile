package com.llamamobile.sdkexample

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.llamamobile.sdkexample.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    lateinit var appState: AppState

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)

        // Initialize app state FIRST before setting content view (prevents fragment inflation issues)
        appState = AppState()
        appState.init(this)

        setContentView(binding.root)

        // Set up navigation with standard approach
        setupNavigation()
    }

    private fun setupNavigation() {
        try {
            // Get NavHostFragment
            val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment_activity_main)
                as NavHostFragment
            
            // Get NavController
            val navController = navHostFragment.navController
            
            // Set navigation graph programmatically AFTER appState is initialized
            navController.setGraph(R.navigation.mobile_navigation)
            
            // Add navigation error listener
            navController.addOnDestinationChangedListener {
                _, destination, _ ->
                android.util.Log.d("MainActivity", "Navigating to destination: ${destination.label}")
            }
            
            // Set up bottom navigation with custom listener to fix NavigationUI crash
            val navView: BottomNavigationView = binding.navView
            
            // Custom navigation item selected listener to avoid NavigationUI crash
            navView.setOnItemSelectedListener {
                item ->
                // Get destination ID from menu item
                val destinationId = item.itemId
                
                try {
                    // Try to navigate directly without explicitly accessing graph
                    navController.navigate(destinationId)
                    true
                } catch (e: IllegalStateException) {
                    // Catch the specific "You must call setGraph() before calling getGraph()" exception
                    android.util.Log.e("MainActivity", "Navigation graph not ready: ${e.message}")
                    android.widget.Toast.makeText(this, "Navigation error: Please try again", android.widget.Toast.LENGTH_SHORT).show()
                    false
                } catch (e: Exception) {
                    // Catch any other navigation exceptions to prevent crash
                    android.util.Log.e("MainActivity", "Navigation error: ${e.message}")
                    e.printStackTrace()
                    android.widget.Toast.makeText(this, "Navigation error: ${e.message}", android.widget.Toast.LENGTH_SHORT).show()
                    false
                }
            }
            
            android.util.Log.d("MainActivity", "Navigation setup completed successfully")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Navigation setup error: ${e.message}")
            e.printStackTrace()
            // Show error message
            android.widget.Toast.makeText(this, "Navigation setup error: ${e.message}", android.widget.Toast.LENGTH_LONG).show()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release SDK resources
        appState.unloadModel()
    }
}