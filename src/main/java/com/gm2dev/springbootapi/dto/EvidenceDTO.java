package com.gm2dev.springbootapi.dto;

import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EvidenceDTO {
    private String id;
    @NotBlank(message = "Testimony is required")
    @Size(max = 255, min = 20, message = "Testimony must be between 20 and 255 characters")
    private String testimony;
    private LocalDateTime dateTime;
    @NotBlank(message = "Created by is required")
    @Size(max = 100, message = "Created by must be less than 100 characters")
    private String createdBy;
}
