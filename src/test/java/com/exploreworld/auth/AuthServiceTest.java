package com.exploreworld.auth;

import com.exploreworld.user.User;
import com.exploreworld.user.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthService service;

    private void assertStatus(Throwable thrown, HttpStatus expected) {
        assertThat(thrown).isInstanceOf(ResponseStatusException.class);
        assertThat(((ResponseStatusException) thrown).getStatusCode()).isEqualTo(expected);
    }

    // ---------- register ----------

    @Test
    @DisplayName("register: e-postayı küçük harfe çevirir, şifreyi hash'leyerek kaydeder")
    void register_savesNormalizedEmailAndHashedPassword() {
        when(passwordEncoder.encode("12345678")).thenReturn("HASHED");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UserResponse response = service.register(
                new RegisterRequest("  Asli@Test.COM ", "12345678", "Aslı"));

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        User saved = captor.getValue();

        assertThat(saved.getEmail()).isEqualTo("asli@test.com");
        assertThat(saved.getPasswordHash()).isEqualTo("HASHED");
        assertThat(saved.getPasswordHash()).isNotEqualTo("12345678");
        assertThat(response.email()).isEqualTo("asli@test.com");
    }

    @Test
    @DisplayName("register: aynı e-posta zaten varsa 409 döner ve kayıt yapmaz")
    void register_existingEmail_throwsConflict() {
        when(userRepository.existsByEmail("asli@test.com")).thenReturn(true);

        assertThatThrownBy(() -> service.register(
                new RegisterRequest("Asli@Test.com", "12345678", "Aslı")))
                .satisfies(e -> assertStatus(e, HttpStatus.CONFLICT));

        verify(userRepository, never()).save(any(User.class));
    }

    // ---------- login ----------

    @Test
    @DisplayName("login: doğru e-posta ve şifre ile token döner")
    void login_validCredentials_returnsToken() {
        User user = new User("asli@test.com", "HASHED", "Aslı");
        when(userRepository.findByEmail("asli@test.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("12345678", "HASHED")).thenReturn(true);
        when(jwtService.generateToken(user)).thenReturn("jwt-token");

        TokenResponse response = service.login(new LoginRequest("asli@test.com", "12345678"));

        assertThat(response.token()).isEqualTo("jwt-token");
    }

    @Test
    @DisplayName("login: yanlış şifrede 401 döner ve token üretmez")
    void login_wrongPassword_throwsUnauthorized() {
        User user = new User("asli@test.com", "HASHED", "Aslı");
        when(userRepository.findByEmail("asli@test.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("yanlis", "HASHED")).thenReturn(false);

        assertThatThrownBy(() -> service.login(new LoginRequest("asli@test.com", "yanlis")))
                .satisfies(e -> assertStatus(e, HttpStatus.UNAUTHORIZED));

        verifyNoInteractions(jwtService);
    }

    @Test
    @DisplayName("login: kayıtlı olmayan e-postada 401 döner")
    void login_unknownEmail_throwsUnauthorized() {
        when(userRepository.findByEmail("yok@test.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.login(new LoginRequest("yok@test.com", "12345678")))
                .satisfies(e -> assertStatus(e, HttpStatus.UNAUTHORIZED));

        verifyNoInteractions(jwtService);
    }

    @Test
    @DisplayName("login: e-posta boşluk ve büyük harfe duyarsızdır")
    void login_normalizesEmail() {
        User user = new User("asli@test.com", "HASHED", "Aslı");
        when(userRepository.findByEmail("asli@test.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("12345678", "HASHED")).thenReturn(true);
        when(jwtService.generateToken(user)).thenReturn("jwt-token");

        TokenResponse response = service.login(new LoginRequest("  ASLI@Test.com ", "12345678"));

        assertThat(response.token()).isEqualTo("jwt-token");
    }
}