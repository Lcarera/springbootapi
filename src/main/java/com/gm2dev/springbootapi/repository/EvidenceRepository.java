package com.gm2dev.springbootapi.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.gm2dev.springbootapi.entity.Evidence;

public interface EvidenceRepository extends JpaRepository<Evidence, String> {

}
