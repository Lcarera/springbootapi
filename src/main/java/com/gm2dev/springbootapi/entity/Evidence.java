package com.gm2dev.springbootapi.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "evidence")
public class Evidence {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @NotBlank(message = "Testimony is required")
    @Size(max = 255, min = 20, message = "Testimony must be between 20 and 255 characters")
    private String testimony;

    @CreationTimestamp
    private LocalDateTime dateTime;

    @NotBlank(message = "Created by is required")
    @Size(max = 100, message = "Created by must be less than 100 characters")
    private String createdBy;
    
}
