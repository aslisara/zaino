package com.exploreworld.sticker;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class StickerService {

    private final StickerRepository repository;

    public StickerService(StickerRepository repository) {
        this.repository = repository;
    }

    public StickerResponse add(Long userId, StickerRequest request) {
        String country = request.country().trim();
        String city = blankToNull(request.city());

        boolean exists = (city == null)
                ? repository.existsByUserIdAndCountryIgnoreCaseAndCityIsNull(userId, country)
                : repository.existsByUserIdAndCountryIgnoreCaseAndCityIgnoreCase(userId, country, city);
        if (exists) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Bu sticker zaten var");
        }

        Sticker saved = repository.save(
                new Sticker(userId, country, city, request.visitedOn(), blankToNull(request.note())));
        return StickerResponse.from(saved);
    }

    public List<StickerResponse> list(Long userId) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(StickerResponse::from)
                .toList();
    }

    public void delete(Long userId, Long id) {
        Sticker sticker = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sticker bulunamadı"));
        repository.delete(sticker);
    }

    private static String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}