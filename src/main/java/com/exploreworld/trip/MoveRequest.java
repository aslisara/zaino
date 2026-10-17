package com.exploreworld.trip;

import jakarta.validation.constraints.Min;

public record MoveRequest(@Min(1) int dayNumber, @Min(1) int position) {}