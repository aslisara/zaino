package com.exploreworld.profile;

import com.exploreworld.user.User;

public record ProfileResponse(
        Long id,
        String email,
        String displayName,
        String bio,
        String accentColor) {

    static ProfileResponse from(User u) {
        return new ProfileResponse(
                u.getId(), u.getEmail(), u.getDisplayName(), u.getBio(), u.getAccentColor());
    }
}
