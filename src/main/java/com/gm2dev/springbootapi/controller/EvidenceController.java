package com.gm2dev.springbootapi.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/evidence")
public class EvidenceController {

    @GetMapping("/")
    public ResponseEntity<String> getEvidence() {
        return ResponseEntity.ok("Evidence");
    }
    
}
