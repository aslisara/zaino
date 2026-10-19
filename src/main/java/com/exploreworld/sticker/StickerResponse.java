package com.exploreworld.sticker;

import java.time.LocalDate;
import java.time.OffsetDateTime;

public record StickerResponse(
        Long id,
        String country,
        String city,
        LocalDate visitedOn,
        String note,
        OffsetDateTime createdAt) {

    static StickerResponse from(Sticker s) {
        return new StickerResponse(
                s.getId(), s.getCountry(), s.getCity(), s.getVisitedOn(), s.getNote(), s.getCreatedAt());
    }
}