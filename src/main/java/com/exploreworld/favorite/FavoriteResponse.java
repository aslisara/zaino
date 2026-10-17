package com.exploreworld.favorite;

import java.time.OffsetDateTime;

public record FavoriteResponse(Long id, String type, String name, String city, String country,
                               OffsetDateTime createdAt) {

    public static FavoriteResponse from(Favorite f) {
        return new FavoriteResponse(f.getId(), f.getType(), f.getName(), f.getCity(),
                f.getCountry(), f.getCreatedAt());
    }
}