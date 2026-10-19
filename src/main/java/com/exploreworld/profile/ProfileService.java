package com.exploreworld.profile;

import com.exploreworld.user.User;
import com.exploreworld.user.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ProfileService {

    private final UserRepository userRepository;

    public ProfileService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public ProfileResponse get(Long userId) {
        return ProfileResponse.from(find(userId));
    }

    @Transactional
    public ProfileResponse update(Long userId, ProfileRequest request) {
        User user = find(userId);

        // Ad boş gönderilirse eskisi korunur
        String displayName = blankToNull(request.displayName());
        if (displayName == null) {
            displayName = user.getDisplayName();
        }

        user.updateProfile(
                displayName,
                blankToNull(request.bio()),
                blankToNull(request.accentColor()));
        return ProfileResponse.from(userRepository.save(user));
    }

    private User find(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));
    }

    private static String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
