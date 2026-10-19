package com.exploreworld.profile;

import com.exploreworld.user.User;
import com.exploreworld.user.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProfileServiceTest {

    private static final Long USER_ID = 1L;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ProfileService service;

    private User existingUser() {
        return new User("asli@test.com", "hash", "Aslı");
    }

    @Test
    void get_returnsProfileOfUser() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(existingUser()));

        ProfileResponse response = service.get(USER_ID);

        assertThat(response.email()).isEqualTo("asli@test.com");
        assertThat(response.displayName()).isEqualTo("Aslı");
        assertThat(response.bio()).isNull();
    }

    @Test
    void get_unknownUser_throwsNotFound() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.get(USER_ID))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void update_changesNameBioAndColor() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(existingUser()));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        ProfileResponse response = service.update(USER_ID,
                new ProfileRequest(" Aslı G. ", " Dünyayı geziyorum ", "#1976D2"));

        assertThat(response.displayName()).isEqualTo("Aslı G.");
        assertThat(response.bio()).isEqualTo("Dünyayı geziyorum");
        assertThat(response.accentColor()).isEqualTo("#1976D2");
        assertThat(response.email()).isEqualTo("asli@test.com");
    }

    @Test
    void update_blankName_keepsOldNameAndBlankBioBecomesNull() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(existingUser()));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        ProfileResponse response = service.update(USER_ID, new ProfileRequest("   ", "  ", null));

        assertThat(response.displayName()).isEqualTo("Aslı");
        assertThat(response.bio()).isNull();
        assertThat(response.accentColor()).isNull();
    }

    @Test
    void update_unknownUser_throwsNotFoundAndSavesNothing() {
        when(userRepository.findById(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(USER_ID, new ProfileRequest("Ad", null, null)))
                .isInstanceOf(ResponseStatusException.class);

        verify(userRepository, never()).save(any());
    }
}
