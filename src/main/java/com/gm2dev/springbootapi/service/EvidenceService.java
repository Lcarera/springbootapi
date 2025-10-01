package com.gm2dev.springbootapi.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.gm2dev.springbootapi.repository.EvidenceRepository;
import com.gm2dev.springbootapi.entity.Evidence;
import java.util.List;

@Service
public class EvidenceService {

    @Autowired
    private EvidenceRepository evidenceRepository;

    public Evidence saveEvidence(Evidence evidence) {
        return evidenceRepository.save(evidence);
    }

    public List<Evidence> getEvidences() {
        return evidenceRepository.findAll();
    }

}
