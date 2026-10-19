package com.exploreworld.profile;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ProfileRequest(
        @Size(max = 80) String displayName,
        @Size(max = 160) String bio,
        @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Renk #RRGGBB biçiminde olmalı") String accentColor) {
}
