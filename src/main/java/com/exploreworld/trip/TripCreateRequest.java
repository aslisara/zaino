package com.exploreworld.trip;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TripCreateRequest(
        @NotBlank @Size(max = 150) String title,
        @NotBlank @Size(max = 100) String city,
        @NotBlank @Size(max = 100) String country,
        @Min(1) @Max(30) int dayCount
) {}