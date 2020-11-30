package com.mw.app.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.sql.Timestamp;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "salaries")
public class Salaries {
	
	@Id
	@Column(name="emp_no", nullable = false)
	private int		empno;
	
	@Column(name="salary", nullable = false)
	private int		salary;
	
	@Column(name="from_date", nullable = false)
	private Timestamp	fromdate;
	
	@Column(name="to_date", nullable = false)
	private Timestamp	todate;

	@Override
	public String toString() {
		return "SalariesDTO{" + empno + "," + salary + "," + fromdate + "," + todate + "}";
	}
}