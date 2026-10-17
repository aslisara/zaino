
package com.exploreworld.favorite;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record FavoriteRequest(
        @NotBlank @Pattern(regexp = "PLACE|FOOD|RESTAURANT|CITY") String type,
        @NotBlank @Size(max = 200) String name,
        @NotBlank @Size(max = 100) String city,
        @NotBlank @Size(max = 100) String country
) {}