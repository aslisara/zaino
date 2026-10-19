package com.exploreworld.sticker;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StickerRepository extends JpaRepository<Sticker, Long> {

    List<Sticker> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<Sticker> findByIdAndUserId(Long id, Long userId);

    boolean existsByUserIdAndCountryIgnoreCaseAndCityIgnoreCase(Long userId, String country, String city);

    boolean existsByUserIdAndCountryIgnoreCaseAndCityIsNull(Long userId, String country);
}