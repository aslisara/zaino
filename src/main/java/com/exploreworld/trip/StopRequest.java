package com.exploreworld.trip;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record StopRequest(
        @Min(1) int dayNumber,
        @NotBlank @Size(max = 200) String name,
        Double latitude,
        Double longitude,
        @Size(max = 500) String note
) {}