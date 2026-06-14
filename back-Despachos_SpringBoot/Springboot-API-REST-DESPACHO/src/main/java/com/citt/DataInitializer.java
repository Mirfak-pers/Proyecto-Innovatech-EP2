package com.citt;

import com.citt.persistence.entity.Despacho;
import com.citt.persistence.repository.DespachoRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    private final DespachoRepository despachoRepository;

    public DataInitializer(DespachoRepository despachoRepository) {
        this.despachoRepository = despachoRepository;
    }

    @Override
    public void run(String... args) {
        if (despachoRepository.count() == 0) {
            Despacho d1 = new Despacho();
            d1.setFechaDespacho(LocalDate.of(2024, 5, 12));
            d1.setPatenteCamion("BCDF12");
            d1.setIntento(1);
            d1.setIdCompra(1L);
            d1.setDireccionCompra("Av. Irarrázaval 890, Ñuñoa");
            d1.setValorCompra(18990L);
            d1.setDespachado(false);

            Despacho d2 = new Despacho();
            d2.setFechaDespacho(LocalDate.of(2024, 5, 20));
            d2.setPatenteCamion("GHJK45");
            d2.setIntento(2);
            d2.setIdCompra(2L);
            d2.setDireccionCompra("Los Aromos 321, Temuco");
            d2.setValorCompra(33000L);
            d2.setDespachado(false);

            Despacho d3 = new Despacho();
            d3.setFechaDespacho(LocalDate.of(2024, 6, 3));
            d3.setPatenteCamion("MNPQ78");
            d3.setIntento(1);
            d3.setIdCompra(3L);
            d3.setDireccionCompra("Gran Avenida 555, San Miguel");
            d3.setValorCompra(27500L);
            d3.setDespachado(true);

            despachoRepository.saveAll(List.of(d1, d2, d3));
        }
    }
}
