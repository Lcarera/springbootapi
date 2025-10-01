package com.gm2dev.springbootapi.controller;

import com.gm2dev.springbootapi.entity.Evidence;
import com.gm2dev.springbootapi.mapper.EvidenceMapper;
import com.gm2dev.springbootapi.service.EvidenceService;
import jakarta.validation.ConstraintViolationException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import com.gm2dev.springbootapi.dto.EvidenceDTO;
import jakarta.validation.Valid;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/evidence")
public class EvidenceController {

    private final EvidenceService evidenceService;
    private final EvidenceMapper evidenceMapper;


    @GetMapping
    public ResponseEntity<List<EvidenceDTO>> getEvidence() {
        List<Evidence> evidences = evidenceService.getEvidences();
        List<EvidenceDTO> evidenceDTOS = evidences.stream().map(evidenceMapper::toDTO).toList();
        return ResponseEntity.ok(evidenceDTOS);
    }

    @PostMapping
    public ResponseEntity<String> createEvidence(@RequestBody @Valid EvidenceDTO evidenceDTO) {
        try {
            Evidence newEvidence = evidenceService.saveEvidence(evidenceMapper.toEntity(evidenceDTO));
            String location = ServletUriComponentsBuilder.fromCurrentRequest()
                    .path("/{id}").buildAndExpand(newEvidence.getId()).toString();
            return ResponseEntity.created(URI.create(location)).body("Evidence created correctly!");
        } catch (ConstraintViolationException e) {
            System.out.println(e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return ResponseEntity.internalServerError().body("Error creating evidence");
        }
    }
    
}
