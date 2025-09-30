package com.gm2dev.springbootapi.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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
}
