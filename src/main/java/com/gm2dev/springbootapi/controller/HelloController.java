package com.gm2dev.springbootapi.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.info.BuildProperties;
import org.springframework.core.env.Environment;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/hello")
public class HelloController {

    private static final Logger logger = LoggerFactory.getLogger(HelloController.class);
    
    @Autowired
    private Environment environment;
    
    @Autowired(required = false)
    private BuildProperties buildProperties;

    @GetMapping
    public ResponseEntity<String> get() {
        logger.info("Hello Logger!");
        return ResponseEntity.ok("Hello World!");
    }
    
    @GetMapping("/profile")
    public ResponseEntity<Map<String, Object>> getProfileInfo() {
        logger.info("Getting profile information");
        
        Map<String, Object> profileInfo = new HashMap<>();
        
        // Get active profiles
        String[] activeProfiles = environment.getActiveProfiles();
        profileInfo.put("activeProfiles", activeProfiles.length > 0 ? Arrays.asList(activeProfiles) : Arrays.asList("default"));
        
        // Get default profiles
        String[] defaultProfiles = environment.getDefaultProfiles();
        profileInfo.put("defaultProfiles", Arrays.asList(defaultProfiles));
        
        // Get application name
        String appName = environment.getProperty("spring.application.name", "Unknown");
        profileInfo.put("applicationName", appName);
        
        // Get server port
        String serverPort = environment.getProperty("server.port", "8080");
        profileInfo.put("serverPort", serverPort);
        
        return ResponseEntity.ok(profileInfo);
    }
    
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        logger.info("Getting application status");
        
        Map<String, Object> status = new HashMap<>();
        
        // Application status
        status.put("status", "UP");
        status.put("version", getApplicationVersion());
        status.put("timestamp", java.time.Instant.now().toString());
        
        // Build information (if available)
        if (buildProperties != null) {
            Map<String, Object> buildInfo = new HashMap<>();
            buildInfo.put("name", buildProperties.getName());
            buildInfo.put("group", buildProperties.getGroup());
            buildInfo.put("version", buildProperties.getVersion());
            buildInfo.put("buildTime", buildProperties.getTime());
            status.put("build", buildInfo);
        }
        
        // Runtime information
        Runtime runtime = Runtime.getRuntime();
        Map<String, Object> memory = new HashMap<>();
        memory.put("totalMemory", runtime.totalMemory());
        memory.put("freeMemory", runtime.freeMemory());
        memory.put("usedMemory", runtime.totalMemory() - runtime.freeMemory());
        memory.put("maxMemory", runtime.maxMemory());
        status.put("memory", memory);
        
        // System information
        Map<String, Object> system = new HashMap<>();
        system.put("javaVersion", System.getProperty("java.version"));
        system.put("osName", System.getProperty("os.name"));
        system.put("osArch", System.getProperty("os.arch"));
        status.put("system", system);
        
        return ResponseEntity.ok(status);
    }
    
    private String getApplicationVersion() {
        // Try to get version from BuildProperties first
        if (buildProperties != null) {
            return buildProperties.getVersion();
        }
        
        // Fallback to implementation version from manifest
        Package pkg = this.getClass().getPackage();
        if (pkg != null && pkg.getImplementationVersion() != null) {
            return pkg.getImplementationVersion();
        }
        
        // Last resort: try to get from environment or use unknown
        return environment.getProperty("app.version", "unknown");
    }
}
