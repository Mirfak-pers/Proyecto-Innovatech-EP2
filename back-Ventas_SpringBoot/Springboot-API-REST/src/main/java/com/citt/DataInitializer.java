package com.citt;

import com.citt.persistence.entity.Venta;
import com.citt.persistence.repository.VentaRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    private final VentaRepository ventaRepository;

    public DataInitializer(VentaRepository ventaRepository) {
        this.ventaRepository = ventaRepository;
    }

    @Override
    public void run(String... args) {
        if (ventaRepository.count() == 0) {
            ventaRepository.saveAll(List.of(
                Venta.builder()
                    .direccionCompra("Av. Providencia 1234, Santiago")
                    .valorCompra(29990)
                    .fechaCompra(LocalDate.of(2024, 5, 10))
                    .despachoGenerado(false)
                    .build(),
                Venta.builder()
                    .direccionCompra("Calle Los Olivos 456, Viña del Mar")
                    .valorCompra(15490)
                    .fechaCompra(LocalDate.of(2024, 5, 18))
                    .despachoGenerado(false)
                    .build(),
                Venta.builder()
                    .direccionCompra("Pasaje El Roble 789, Concepción")
                    .valorCompra(42000)
                    .fechaCompra(LocalDate.of(2024, 6, 1))
                    .despachoGenerado(false)
                    .build()
            ));
        }
    }
}
