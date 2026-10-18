package com.exploreworld.auth;

import com.exploreworld.user.User;
import com.exploreworld.user.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public UserResponse register(RegisterRequest request) {
        String email = normalize(request.email());

        if (userRepository.existsByEmail(email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Bu e-posta zaten kayıtlı");
        }

        User user = new User(
                email,
                passwordEncoder.encode(request.password()),
                request.displayName());

        User saved = userRepository.save(user);
        // UYARI: UserResponse'un yapısı sende farklıysa sadece bu satırı kendi koduna göre düzelt.
        return new UserResponse(saved.getId(), saved.getEmail(), saved.getDisplayName());
    }

    public TokenResponse login(LoginRequest request) {
        String email = normalize(request.email());

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "E-posta veya şifre hatalı"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "E-posta veya şifre hatalı");
        }

        return new TokenResponse(jwtService.generateToken(user));
    }

    // Locale.ROOT: Türkçe bilgisayarda "I" harfi "ı" olmasın diye
    private String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}