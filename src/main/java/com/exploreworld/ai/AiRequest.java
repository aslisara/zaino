package com.exploreworld.ai;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AiRequest(@NotBlank @Size(max = 2000) String prompt) {}