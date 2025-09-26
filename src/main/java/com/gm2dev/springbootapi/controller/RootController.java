package com.gm2dev.springbootapi.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/")
public class RootController {
    
    @GetMapping
    public String root() {
        return "redirect:/hello";
    }
}
