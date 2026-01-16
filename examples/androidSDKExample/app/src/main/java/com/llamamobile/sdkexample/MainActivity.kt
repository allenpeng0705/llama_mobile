package com.llamamobile.sdkexample

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.findNavController
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.llamamobile.sdkexample.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    lateinit var appState: AppState

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Initialize app state first (now runs in background thread)
        appState = AppState()
        appState.init(this)

        // Set up navigation with delayed navGraph setup
        setupNavigation()
    }

    private fun setupNavigation() {
        // Get the NavHostFragment
        val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment_activity_main)
            as androidx.navigation.fragment.NavHostFragment
        
        // Get the navigation controller
        val navController = navHostFragment.navController
        
        // Set up bottom navigation
        val navView: BottomNavigationView = binding.navView
        navView.setupWithNavController(navController)
        
        // Set the navigation graph after a short delay to avoid race conditions
        Handler(Looper.getMainLooper()).postDelayed({
            navController.setGraph(R.navigation.mobile_navigation)
        }, 100)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release SDK resources
        appState.unloadModel()
    }
}