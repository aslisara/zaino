package com.exploreworld.sticker;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record StickerRequest(
        @NotBlank @Size(max = 100) String country,
        @Size(max = 100) String city,
        LocalDate visitedOn,
        @Size(max = 500) String note) {
}