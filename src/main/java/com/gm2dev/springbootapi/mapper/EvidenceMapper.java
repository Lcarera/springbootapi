package com.gm2dev.springbootapi.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import com.gm2dev.springbootapi.entity.Evidence;
import com.gm2dev.springbootapi.dto.EvidenceDTO;

@Mapper(componentModel = "spring")
public interface EvidenceMapper {

    Evidence toEntity(EvidenceDTO evidenceDTO);

    EvidenceDTO toDTO(Evidence evidence);

}
